-- license:BSD-3-Clause
-- MAME 0.289 官方插件：多路输入镜像（离线单机、本人所有）
--
-- v4.0.0 —— 按用户需求重构
--   1) 按钮数量可配（1..16）：菜单里一行「按钮数量」，左右键调整；
--      逐项列表只显示到该数量（游戏本身有几个就显示几个，不会凭空造）。
--   2) 顺序固定为：上、下、左、右、按钮1..N（不再按 type 数字乱序）。
--   3) 支持 1P → 2P / 3P / 4P：每一行可以选择镜像到哪个玩家。
--   4) 总开关用左右键切换（不会因为显示 OFF 而变成不可选）。
--
-- 定位原理（不依赖语言）：field.type（输入类型枚举，纯数字）+ field.player（玩家号，
--   0=P1 1=P2 2=P3 3=P4）；DIP 开关用 field.type_class 排除。
--
-- 持久化：<homepath>/copilot2p/settings.json

local exports = {
	name = 'copilot2p',
	version = '5.0.1',
	description = 'Multi-player input mirror: map P1 keys to P2/P3/P4 with per-key toggles',
	license = 'BSD-3-Clause',
	author = { name = 'local' } }

local copilot2p = exports

local frame_subscription, prestart_subscription, stop_subscription

local input_manager = nil
local ioport = nil
local entries = {}         -- 有序列表：{ kind='dir'|'btn', sem='UP'..., p1=field, name=..., targets={[player]=field} }
local overridden = {}

local dir_path = nil
local frame_no = 0
local last_error = ''
local diag = {}
local built = false

-- MAME 输入类型基准（IPT_ 枚举，与官方 input type 一致）
--   方向：47=UP 48=DOWN 49=LEFT 50=RIGHT
--   按钮：60=BUTTON1 ... 75=BUTTON16
local IPT = {
	UP = 47, DOWN = 48, LEFT = 49, RIGHT = 50,
	BUTTON1 = 60, BUTTON2 = 61, BUTTON3 = 62, BUTTON4 = 63,
	BUTTON5 = 64, BUTTON6 = 65, BUTTON7 = 66, BUTTON8 = 67,
	BUTTON9 = 68, BUTTON10 = 69, BUTTON11 = 70, BUTTON12 = 71,
	BUTTON13 = 72, BUTTON14 = 73, BUTTON15 = 74, BUTTON16 = 75,
}
local DIR_ORDER = { 'UP', 'DOWN', 'LEFT', 'RIGHT' }
local DIR_LABEL = { UP = '上', DOWN = '下', LEFT = '左', RIGHT = '右' }
local PLAYER_LABEL = { [1] = 'P2', [2] = 'P3', [3] = 'P4' }   -- player 索引（1=P2）
-- v4.8：源玩家标签（0=P1..3=P4），供"镜像源"选择用
local PLAYER_FULL = { [0] = 'P1', [1] = 'P2', [2] = 'P3', [3] = 'P4' }
local ui_src = 0            -- 菜单当前正在编辑哪个源的映射（仅 UI 游标，不持久化）

local settings = {
	master = true,
	button_count = 4,       -- 当前生效的按钮数量（1..16）
	enabled = {},           -- [sem] = bool    每个键是否镜像
	targets = {},           -- [sem] = { [playerIndex]=true, ... }  同时镜像到哪些玩家
	                        --   playerIndex: 1=P2 2=P3 3=P4；缺省=用 default_targets

	-- ===== 默认值配置（v4.3 新增）=====
	-- 这三项是"模板"：启动/新开局时按它们初始化，菜单里改它们会立即同步到当前状态。
	default_master = true,            -- 默认总开关 ON/OFF
	default_targets = { [1] = true }, -- 默认镜像到哪些玩家（1=P2 2=P3 3=P4）
	default_button_count = 4,         -- 默认按钮数量


	-- ===== 多源镜像（v4.8）=====
	-- sources[src][sem][dst] = true   src=源玩家(0=P1..3=P4) dst=目标玩家(1..3)
	-- 旧 targets[sem][dst] 会在加载时自动迁移为 sources[0][sem][dst]
	sources = {},
	src_enabled = { [0] = true, [1] = false, [2] = false, [3] = false }, -- 各源总开关
	src_count = 1,            -- 参与镜像的源数量（1..4）
}

-- ---------- 工具 ----------
local function safe(fn, default)
	local ok, v = pcall(fn)
	if ok then return v end
	return default
end

local TYPE_CLASS_ALLOW = { controller = true }
local TYPE_BLOCK = { [5] = true, [6] = true, [7] = true }

-- 把 field.type（数字）映射到语义键，纯数值、与界面语言无关
local function sem_of_type(ty)
	local n = tonumber(ty)
	if not n then return nil end
	for sem, val in pairs(IPT) do
		if val == n then return sem end
	end
	return nil
end

local function collect_all()
	local recs = {}
	local sk_c = 0
	for tag, port in pairs(ioport.ports) do
		local fields = safe(function() return port.fields end, nil)
		if fields then
			for name, f in pairs(fields) do
				local analog = safe(function() return f.is_analog end, true)
				local enabled = safe(function() return f.enabled end, false)
				local ty = safe(function() return f.type end, nil)
				local tc = safe(function() return f.type_class end, nil)
				local is_ctrl = true
				if tc ~= nil then
					is_ctrl = TYPE_CLASS_ALLOW[tostring(tc)] == true
					if not is_ctrl then sk_c = sk_c + 1 end
				elseif ty ~= nil and TYPE_BLOCK[tonumber(ty)] then
					is_ctrl = false
				end
				if is_ctrl and (not analog) and enabled then
					table.insert(recs, {
						port = tag, name = tostring(name), field = f,
						portobj = port,
						mask = safe(function() return f.mask end, nil),
						player = safe(function() return f.player end, nil),
						type = ty, type_class = tc,
						defvalue = safe(function() return f.defvalue end, 0),
					})
				end
			end
		end
	end
	diag_skipped_class = sk_c
	return recs
end

-- 建有序条目：方向（上下左右）→ 按钮1..N；每项记录 1P 字段与各玩家目标字段
local function build_entries()
	entries = {}
	input_manager = manager.machine.input
	ioport = manager.machine.ioport

	local recs = collect_all()

	-- by[player][sem] = field（每玩家每语义取第一个）
	local by = {}
	local d = {
		records = #recs, players_found = {}, sem_found = {},
		skipped_by_class = diag_skipped_class or 0,
		samples = {},
	}
	for _, r in ipairs(recs) do
		local pl = r.player
		local sem = sem_of_type(r.type)
		if sem and pl ~= nil then
			by[pl] = by[pl] or {}
			if not by[pl][sem] then
				by[pl][sem] = r
				table.insert(d.sem_found, string.format('P%s:%s', tostring(pl + 1), sem))
			end
		end
	end
	for pl, _ in pairs(by) do table.insert(d.players_found, pl + 1) end
	table.sort(d.players_found)

	-- 按固定顺序生成条目
	-- v4.8：fields[0..3] 记录所有玩家的同语义字段（0=P1..3=P4），
	--       多源镜像时任意玩家都可以当源，任意玩家都可以当目标。
	local function add_entry(kind, sem)
		local e = {
			kind = kind, sem = sem,
			fields = {},          -- [playerIndex 0..3] = field
			field_names = {},     -- [playerIndex] = 显示名
			ports = {}, masks = {}, defs = {},   -- v4.9.11 方案B：读字段值用
		}
		local any = false
		for pli = 0, 3 do
			local t = by[pli] and by[pli][sem]
			if t then
				e.fields[pli] = t.field
				e.field_names[pli] = t.name
				e.ports[pli] = t.portobj
				e.masks[pli] = t.mask
				e.defs[pli] = t.defvalue
				any = true
			end
		end
		if not any then return end
		table.insert(entries, e)
	end

	for _, sem in ipairs(DIR_ORDER) do add_entry('dir', sem) end
	for i = 1, 16 do
		local sem = 'BUTTON' .. i
		add_entry('btn', sem)
	end

	-- 样本诊断
	for _, r in ipairs(recs) do
		if #d.samples < 20 then
			table.insert(d.samples, string.format('%s|t=%s|p=%s',
				tostring(r.name), tostring(r.type), tostring(r.player)))
		end
	end
	diag = d
	emu.print_verbose(string.format('[copilot2p] recs=%d entries=%d players=%s',
		d.records, #entries, table.concat(d.players_found, ',')))
end

-- ---------- 持久化 ----------
-- ============ 配置持久化（v4.7：按 ROM 独立）============
-- 三层文件：
--   settings_default.json       全局默认模板（跨 ROM 共用，菜单可"保存当前为默认"）
--   settings_<romname>.json     每个游戏独立（互不污染）
--   settings.json               旧版遗留（仅作迁移来源，读到后会自动拆到上面两个）
local rom_name = nil            -- 缓存的 romname，避免频繁调用
local menu_verify = ''          -- 菜单自检结果（v4.8 用）

-- 前向声明：load_settings 会用到这两个，必须先占位再赋值
local save_settings
local save_defaults

local function cur_rom()
	if rom_name then return rom_name end
	local ok, n = pcall(function() return emu.romname() end)
	rom_name = ok and tostring(n) or 'unknown'
	return rom_name
end

local function default_settings_path()
	return dir_path and (dir_path .. '/settings_default.json') or nil
end

local function rom_settings_path()
	local r = cur_rom()
	-- romname 可能含路径分隔符或非法字符，做一次清洗
	r = r:gsub('[/\\:*?"<>|]', '_')
	return dir_path and (dir_path .. '/settings_' .. r .. '.json') or nil
end

local function legacy_settings_path()
	return dir_path and (dir_path .. '/settings.json') or nil
end

-- 读一个 JSON 文件，返回 table 或 nil
local function read_json_file(p)
	if not p then return nil end
	local f = io.open(p, 'r')
	if not f then return nil end
	local text = f:read('a'); f:close()
	if not text or text == '' then return nil end
	local ok, obj = pcall(function() return require('json').parse(text) end)
	if not ok or type(obj) ~= 'table' then return nil end
	return obj
end

-- 把一个配置 table 应用到 settings（obj 为 nil 时跳过）
--   注意：defaults_only=true 时只应用"默认值"三件套（模板层）
local function apply_settings_obj(obj, defaults_only)
	if type(obj) ~= 'table' then return end

	-- ===== 默认值三件套（模板层也只用这些）=====
	if type(obj.default_master) == 'boolean' then
		settings.default_master = obj.default_master
	end
	if tonumber(obj.default_button_count) then
		settings.default_button_count = math.max(1,
			math.min(16, math.floor(tonumber(obj.default_button_count))))
	end
	if type(obj.default_targets) == 'table' then
		local m = {}
		for k, on in pairs(obj.default_targets) do
			local pi = tonumber(k)
			if pi and on and pi >= 1 and pi <= 3 then m[pi] = true end
		end
		local any = false
		for _ in pairs(m) do any = true end
		if any then settings.default_targets = m end
	end

	if defaults_only then return end

	-- ===== 当前生效值 =====
	if type(obj.master) == 'boolean' then
		settings.master = obj.master
	else
		settings.master = settings.default_master
	end
	if tonumber(obj.button_count) then
		settings.button_count = math.max(1, math.min(16, math.floor(tonumber(obj.button_count))))
	else
		settings.button_count = settings.default_button_count
	end
	-- ===== v4.8 多源镜像配置 =====
	if type(obj.sources) == 'table' then
		local out = {}
		for skey, per_sem in pairs(obj.sources) do
			local src = tonumber(skey)
			if src and src >= 0 and src <= 3 and type(per_sem) == 'table' then
				local m = {}
				for sem, v in pairs(per_sem) do
					if type(v) == 'table' then
						local d = {}
						for k, on in pairs(v) do
							local pi = tonumber(k)
							if on and pi and pi >= 1 and pi <= 3 then d[pi] = true end
						end
						m[sem] = d
					end
				end
				out[src] = m
			end
		end
		settings.sources = out
	end
	if type(obj.src_enabled) == 'table' then
		for k, v in pairs(obj.src_enabled) do
			local s = tonumber(k)
			if s and s >= 0 and s <= 3 then settings.src_enabled[s] = (v == true) end
		end
	end

	-- ===== 旧格式迁移：targets[sem][dst] / enabled[sem] → sources[0] =====
	-- 旧模型源固定是 P1，因此迁移到 sources[0]；enabled=false 迁移为空目标集。
	-- 只有当文件里没有新格式 sources 时才做迁移，避免覆盖新配置。
	if type(obj.sources) ~= 'table' then
		local base = {}
		if type(obj.targets) == 'table' then
			for sem, v in pairs(obj.targets) do
				local d = {}
				if type(v) == 'table' then
					for k, on in pairs(v) do
						local pi = tonumber(k)
						if on and pi then d[pi] = true end
					end
				elseif tonumber(v) then
					d[tonumber(v)] = true
				end
				base[sem] = d
			end
		elseif type(obj.target) == 'table' then
			for sem, v in pairs(obj.target) do
				if tonumber(v) then base[sem] = { [tonumber(v)] = true } end
			end
		end
		if type(obj.enabled) == 'table' then
			for sem, on in pairs(obj.enabled) do
				if on == false then base[sem] = {} end   -- 显式关闭 = 空目标
			end
		end
		if next(base) ~= nil then
			settings.sources[0] = base
			menu_verify = 'migrated_targets_to_sources'
		end
	end

end

-- 加载顺序：先模板层（default），再 ROM 层覆盖
local function load_settings()
	-- 1) 默认模板
	apply_settings_obj(read_json_file(default_settings_path()), true)

	-- 2) 本 ROM 配置（覆盖模板）
	local obj = read_json_file(rom_settings_path())

	-- 3) 若本 ROM 还没有配置，尝试从旧版全局 settings.json 迁移一次
	if not obj then
		local legacy = read_json_file(legacy_settings_path())
		if legacy then
			obj = legacy
			-- 立刻把迁移结果写成本 ROM 配置 + 模板，之后不再读旧文件
			apply_settings_obj(obj, false)
			save_settings()
			save_defaults()
			menu_verify = 'migrated_from_settings.json'
			return
		end
	end

	if obj then
		apply_settings_obj(obj, false)
	else
		-- 全新 ROM：用模板值作为起点
		settings.master = settings.default_master
		settings.button_count = settings.default_button_count
		settings.sources = {}
		settings.src_enabled = { [0] = true, [1] = false, [2] = false, [3] = false }
	end
end

-- 保存本 ROM 配置（只写 settings_<rom>.json，绝不污染其他游戏）
-- ★ 必须赋值给前向声明的 save_settings（L207），不能写 local function ——
--   否则会创建新局部变量遮蔽前向声明，load_settings 的闭包将永远拿到 nil。
save_settings = function()
	local p = rom_settings_path()
	if not p then return end
	local ok, txt = pcall(function() return require('json').stringify(settings) end)
	if not ok then return end
	local f = io.open(p, 'w')
	if f then f:write(txt); f:close() end
end

-- 保存默认模板（只写 default_master / default_targets / default_button_count 三项）
-- ★ 同上：赋值而非 local function，保持前向声明有效。
save_defaults = function()
	local p = default_settings_path()
	if not p then return end
	local tpl = {
		default_master = settings.default_master,
		default_targets = settings.default_targets,
		default_button_count = settings.default_button_count,
	}
	local ok, txt = pcall(function() return require('json').stringify(tpl) end)
	if not ok then return end
	local f = io.open(p, 'w')
	if f then f:write(txt); f:close() end
end

-- 把"当前生效值"存为默认模板（菜单动作）
-- v4.8 修正：旧实现遍历 settings.targets（该字段已废弃、恒为空），
--   导致"保存当前为默认"静默失效。改为从 settings.sources 取当前编辑源的目标组合。
local function save_current_as_default()
	settings.default_master = settings.master
	settings.default_button_count = settings.button_count
	-- 从"当前编辑源"里取第一个非空目标组合作为默认模板
	local ss = settings.sources[ui_src]
	if type(ss) == 'table' then
		for _, d in pairs(ss) do
			if type(d) == 'table' and next(d) ~= nil then
				settings.default_targets = d
				break
			end
		end
	end
	save_defaults()
	save_settings()
end

-- 重置本 ROM 配置（删掉本 ROM 文件，回落模板）
local function reset_rom_settings()
	local p = rom_settings_path()
	if p then
		os.remove(p)
	end
	-- 重新套用模板
	apply_settings_obj(read_json_file(default_settings_path()), true)
	settings.master = settings.default_master
	settings.button_count = settings.default_button_count
	settings.sources = {}
	settings.src_enabled = { [0] = true, [1] = false, [2] = false, [3] = false }
	save_settings()
end

-- 把默认值应用到当前生效状态（对应用户需求：「这里设置以后，上面就跟默认走」）
local function apply_defaults()
	settings.master = settings.default_master
	settings.button_count = settings.default_button_count
	-- 清掉逐项自定义，让所有键回落到 default_targets
	settings.sources = {}
	settings.src_enabled = { [0] = true, [1] = false, [2] = false, [3] = false }
	save_settings()
end

local function write_status(extra)
	if not dir_path then return end
	local payload = {
		plugin = 'copilot2p', version = exports.version,
		rom = cur_rom(), frame = frame_no,
		entries = #entries, master = settings.master,
		button_count = settings.button_count,
		menu_verify = menu_verify,
		last_error = last_error, ts = os.time(), diag = diag,
	}
	if extra then for k, v in pairs(extra) do payload[k] = v end end
	local ok, txt = pcall(function() return require('json').stringify(payload) end)
	if not ok then return end
	local f = io.open(dir_path .. '/plugin_status.json', 'w')
	if f then f:write(txt); f:close() end
end

-- ---------- 镜像 ----------
local function clear_all()
	for field in pairs(overridden) do
		pcall(function() field:clear_value() end)
	end
	overridden = {}
end

local function set_field(field, on)
	if on then
		field:set_value(1)
		overridden[field] = true
	else
		field:clear_value()
		overridden[field] = nil
	end
end

-- ★ v4.9.3 核心修复：连发"松开相"必须用 set_value(0)（程序化强制松开），
--   绝不能用 clear_value()——clear_value 的语义是"恢复物理读取"。
--   旧实现在脉冲 off 相对目标字段 clear_value，若该字段的物理键正被按住
--   （连发作用于玩家自己按住的键时必然如此），字段立刻被物理输入顶回按下，
--   "松开"永远无效 => 连发整体失效（实测：P1 与被控者都不连发）。
--   官方 autofire 没踩这个坑，是因为它连发的是"没被按住的另一个键"。
--   on/off 都属程序化覆盖，统一登记 overridden，由 clear_all 在停用/退出时
--   一次性 clear_value 归还物理控制。

-- 该条目是否在"按钮数量"范围内
local function entry_active(e)
	if e.kind == 'dir' then return true end
	local n = tonumber(e.sem:match('^BUTTON(%d+)$')) or 999
	return n <= (settings.button_count or 4)
end

-- ============ v4.8 多源镜像核心 ============
-- 数据：settings.sources[src][sem][dst] = true
--   src: 0=P1 1=P2 2=P3 3=P4（源玩家）
--   dst: 1=P2 2=P3 3=P4（目标玩家；dst==src 无意义，禁止）
-- 说明：镜像读取的是 field:input_seq（物理键绑定），不是被覆盖后的值，
--       因此 A→B 与 B→A 同时开启只会"互换按键"，不会形成信号回环，
--       无需防环检测。真正需要处理的是"同一目标被多源控制"→ 取 OR。

-- 某源玩家是否参与镜像
local function src_active(src)
	if src == 0 then return settings.src_enabled[0] ~= false end
	return settings.src_enabled[src] == true
end

-- 该条目在源 src 下【已存储】的目标集合。
-- v4.8 语义修正：只要 sources[src][sem] 是 table（哪怕是空表），都算"显式配置过"，
--   返回过滤后的集合（可能为空 = 显式不镜像）。只有压根没有这个键才返回 nil
--   （= 未配置，交给 default_targets 兜底）。
--   若不这样区分，"全部停用/关闭某键"写入的空表会被当成未配置而回落默认，关不掉。
local function entry_stored_dst(e, src)
	local ss = settings.sources[src]
	if type(ss) ~= 'table' then return nil end
	local t = ss[e.sem]
	if type(t) ~= 'table' then return nil end
	local out = {}
	for pi = 1, 3 do
		if pi ~= src and t[pi] and e.fields[pi] then out[pi] = true end
	end
	return out
end

-- 该条目在源 src 下【实际生效】的目标集合
-- 优先级：① 该 (src,sem) 单独设置过 → 用它；② default_targets；③ 第一个存在的目标
local function entry_dst_set(e, src)
	local s = entry_stored_dst(e, src)
	if s then return s end

	local def = settings.default_targets
	if type(def) == 'table' then
		local out = {}
		local any = false
		for pi = 1, 3 do
			if pi ~= src and def[pi] and e.fields[pi] then out[pi] = true; any = true end
		end
		if any then return out end
	end

	local out = {}
	for pi = 1, 3 do
		if pi ~= src and e.fields[pi] then out[pi] = true; break end
	end
	return out
end

-- 收集"控制目标 dst 的所有源"（用于 OR 合成）
local function sources_for_dst(e, dst)
	local out = {}
	for src = 0, 3 do
		if src ~= dst and src_active(src) then
			local dset = entry_dst_set(e, src)
			if dset and dset[dst] then table.insert(out, src) end
		end
	end
	return out
end


-- 读某条目某源玩家的按键状态（物理绑定读取）。
-- ★ v4.9.12 回退方案B：port:read()+defvalue 极性在 xmen 方向键上判反
--   （2P 方向被镜像成振荡=用户所见"方向像被连发"），且自主连发读回
--   自己写的覆盖值会自锁。恢复读 input_seq 物理绑定状态。
--   结论（4.9.10 探针实证）：主控自己物理按住的键无法用 set_value 连发
--   ——每帧物理刷新顶回按下态；主控连发请用 MAME 官方「连发」插件，
--   本插件连发对"无物理竞争的字段"（被控者、映射到别的键）有效。
local function src_pressed(e, src)
	local f = e.fields[src]
	if not f then return false end
	local seq = safe(function() return f:input_seq('standard') end, nil)
	if not seq then return false end
	return safe(function() return input_manager:seq_pressed(seq) end, false)
end


local function tick()
	frame_no = frame_no + 1

	if not built then
		built = true
		local ok, err = pcall(build_entries)
		if not ok then last_error = 'build_entries: ' .. tostring(err) end
		write_status({ phase = 'built' })
	end

	if frame_no % 60 == 0 then write_status() end

	if not settings.master or #entries == 0 then
		clear_all()
		return
	end

	-- ===== v5.0.0 纯镜像（连发功能已移除）=====
	-- 只把【源玩家】按键状态镜像到【被控目标 dst=1..3】(P2/P3/P4)。
	-- P1 字段本插件完全不写：物理按住的键 set_value 会被每帧物理刷新顶回，
	-- 主控连发在插件层不可行（两轮探针实证）；需要连发请用 MAME 官方「连发」插件。
	-- 两阶段快照：先读全部源、再统一写，避免互控同帧振荡。
	for _, e in ipairs(entries) do
		if entry_active(e) then
			local snap = {}
			for pi = 0, 3 do
				if e.fields[pi] then snap[pi] = src_pressed(e, pi) end
			end
			for dst = 1, 3 do
				local dst_field = e.fields[dst]
				if dst_field then
					local srcs = sources_for_dst(e, dst)
					if #srcs > 0 then
						local val = false
						for _, src in ipairs(srcs) do
							if snap[src] then val = true; break end
						end
						pcall(function() set_field(dst_field, val) end)
					elseif overridden[dst_field] then
						pcall(function() dst_field:clear_value() end)
						overridden[dst_field] = nil
					end
				end
			end
		end
	end
end

-- ---------- 菜单（v4.6 动作表方案）----------
-- 核心设计：menu_items() 在生成每一项的同时，把「该索引对应什么动作」写进
--   actions[index] = { kind = '...', sem = ..., pi = ... }
-- menu_callback() 直接查 actions[index]，不做任何减法/偏移计算。
-- 这样无论菜单项数量怎么变（动态按钮行、增减固定项），索引永远正确，
-- 彻底根治「按当前行却改了上一行」的错位。
local last_actions = {}

local function menu_items()
	local items = {}
	local actions = {}

	-- 每次 push 都登记动作（不传 kind 表示纯展示、不可操作）
	local function push(label, value, flags, act)
		table.insert(items, { label, value or '', flags or 'off' })
		actions[#items] = act or nil
	end
	local function head(label, value) push(label, value, 'heading') end
	local function sep() push('---', '', 'off') end
	local function disp(label, value) push(label, value, 'off') end
	local function act(label, value, a) push(label, value, '', a) end
	local function toggle(label, on, a) push(label, (on and 'ON' or 'OFF'), 'lr', a) end
	local function adj(label, value, a) push(label, value, 'lr', a) end

	-- ===== 固定项 =====
	head('1P 联动多玩家', string.format('游戏有 %d 类输入', #entries))
	toggle('总开关（左右键切换）', settings.master, { kind = 'master' })
	act('全部启用', '打开所有源的镜像', { kind = 'all_on' })
	act('全部停用', '关闭所有源的镜像', { kind = 'all_off' })
	adj('按钮数量（左右键调整）',
		string.format('%d 个', settings.button_count or 4), { kind = 'btn_count' })

	-- ===== v4.8 镜像源 =====
	sep()
	head('镜像源（谁控制谁）', '先选源，再逐键设置目标')
	adj('当前编辑源（左右键切换）', PLAYER_FULL[ui_src] or 'P1', { kind = 'ui_src' })
	toggle('启用此源的镜像', src_active(ui_src), { kind = 'src_enable' })

	-- ===== 默认值 =====
	sep()
	head('默认值（新开局/恢复默认时按此初始化）', '改完立即同步到上面')
	toggle('默认总开关', settings.default_master, { kind = 'def_master' })
	local dset = settings.default_targets or { [1] = true }
	local dpick = {}
	for pi = 1, 3 do
		if dset[pi] then table.insert(dpick, PLAYER_LABEL[pi]) end
	end
	adj('默认镜像到',
		(table.concat(dpick, '+') ~= '' and ('镜像到 ' .. table.concat(dpick, '+')) or '镜像到 无'),
		{ kind = 'def_targets' })
	adj('默认按钮数量', string.format('%d 个', settings.default_button_count or 4),
		{ kind = 'def_btn_count' })
	act('恢复默认（套用上面三项）', '把默认值应用到当前设置', { kind = 'apply_defaults' })
	act('保存当前为默认模板', '写入 settings_default.json', { kind = 'save_as_default' })
	act('重置本 ROM 配置', '删除 settings_' .. cur_rom() .. '.json', { kind = 'reset_rom' })

	-- ===== 多控按键（针对"当前编辑源"）=====
	sep()
	head(string.format('逐项（源 %s → 目标）', PLAYER_FULL[ui_src]),
		'回车=开/关　左右键=选目标(可多选)')
	local shown = {}
	for _, e in ipairs(entries) do
		if entry_active(e) and e.fields[ui_src] then table.insert(shown, e) end
	end
	for _, e in ipairs(shown) do
		local label
		if e.kind == 'dir' then
			label = DIR_LABEL[e.sem] or e.sem
		else
			label = string.format('按钮 %s', e.sem:match('^BUTTON(%d+)$') or '?')
		end
		-- 该源在此键上实际生效的目标集合
		local dset = entry_dst_set(e, ui_src)
		local picked = {}
		for pi = 1, 3 do
			if pi ~= ui_src and dset[pi] and e.fields[pi] then
				table.insert(picked, PLAYER_LABEL[pi])
			end
		end
		local ps = (#picked > 0) and table.concat(picked, '+') or '无'
		adj(label, string.format('%s → %s', PLAYER_FULL[ui_src], ps),
			{ kind = 'mirror', sem = e.sem, src = ui_src })
	end


	sep()
	disp('状态', string.format('rom=%s  frame=%d  err=%s',
		tostring(emu.romname()), frame_no, last_error ~= '' and last_error or '-'))

	last_actions = actions

	-- ★ 索引自检（v4.7）：动作表与菜单项必须一一对应。
	--   任何 push 都同时写 items 和 actions，长度不等说明有分支漏登记，
	--   一旦错位就会"按当前行改了别的行"。这里主动检测并暴露到状态文件。
	local op_cnt = 0
	for i = 1, #items do
		local fl = items[i][3]
		if fl == '' or fl == 'lr' or fl == 'on' or fl == 'off' then
			-- 'off' 既可能是纯展示也可能是开关；只对可回车/可左右项强求动作
		end
		if (fl == '' or fl == 'lr') and not actions[i] then
			op_cnt = op_cnt + 1
		end
	end
	local act_cnt = 0
	for _, v in pairs(actions) do
		if v ~= nil then act_cnt = act_cnt + 1 end
	end
	-- 稀疏表不能用 #actions（会停在第一个空洞），改用非 nil 计数
	if act_cnt == 0 and #items > 0 then
		menu_verify = string.format('FAIL actions空 items=%d', #items)
	elseif op_cnt > 0 then
		menu_verify = string.format('FAIL %d 个可操作项无动作', op_cnt)
	else
		menu_verify = string.format('OK %d 项', #items)
	end

	return items
end

-- 固定项共 14 个（1 标题 / 2 总开关 / 3 全部启用 / 4 全部停用 / 5 按钮数量
--   / 6 分隔 / 7 默认值标题 / 8 默认总开关 / 9 默认镜像到 / 10 默认按钮数量
--   / 11 恢复默认 / 12 分隔 / 13 逐项标题）
-- ★ v4.6 核心重构：用「动作表」取代索引计算
--   原因：菜单项数量是动态的（每个按钮可能 1 行或 1+N 行），任何硬编码
--   FIXED_COUNT 都会在增删菜单项后错位——这正是「按当前行却改上一行」的根因。
--   做法：menu_items() 生成时同步产出 actions[index] = {kind=..., ...}，
--        menu_callback() 直接查表，不再做任何减法。
--   这样菜单怎么变，索引都自动正确。
-- ★ v4.9.1 修复：此处原有的 `local last_actions = {}` 是【重复声明】。
--   last_actions 已在 menu_items 之前声明并在其内部赋值；这里再 local 一次
--   会遮蔽前面那个，导致 menu_callback 读到的是永远为空的表 => 全部选项无反应。
--   （探针实测证据：actions_nonnil=0 actions_maxindex=0，而 index/event 均正常）

-- 为给定玩家列表生成所有非空组合（按人数少→多、字典序），供菜单和逐项共用
local function combos_for_avail(avail)
	local combos = {}
	local total = 1
	for _ = 1, #avail do total = total * 2 end
	for mask = 1, total - 1 do
		local combo = {}
		for bit = 1, #avail do
			if math.floor(mask / (2 ^ (bit - 1))) % 2 == 1 then
				table.insert(combo, avail[bit])
			end
		end
		table.insert(combos, combo)
	end
	table.sort(combos, function(a, b)
		if #a ~= #b then return #a < #b end
		for i = 1, math.min(#a, #b) do
			if a[i] ~= b[i] then return a[i] < b[i] end
		end
		return false
	end)
	return combos
end

-- v4.6 动作表分发：menu_callback 直接查 last_actions[index]，不做任何偏移计算
local function menu_callback(index, event)
	local is_select = (event == 'select')
	local is_left = (event == 'left')
	local is_right = (event == 'right')

	local a = last_actions[index]

	if not a then return false end
	local k = a.kind

	-- ===== 总开关 =====
	if k == 'master' then
		if is_select or is_left or is_right then
			settings.master = not settings.master
			if not settings.master then clear_all() end
			save_settings()
			return true
		end
		return false

	-- ===== 全部启用 / 停用 =====
	-- v4.8 语义：作用于"当前编辑源"（ui_src），与镜像源模型一致
	elseif k == 'all_on' then
		if is_select then
			settings.master = true
			settings.src_enabled[ui_src] = true
			-- 该源所有键回到"跟随默认目标"
			settings.sources[ui_src] = nil
			save_settings()
			return true
		end
		return false
	elseif k == 'all_off' then
		if is_select then
			-- 只关这个源，不影响其他源与总开关
			settings.src_enabled[ui_src] = false
			clear_all()
			save_settings()
			return true
		end
		return false

	-- ===== 当前按钮数量 =====
	elseif k == 'btn_count' then
		if is_left or is_right then
			local n = settings.button_count or 4
			if is_right then n = n + 1 else n = n - 1 end
			settings.button_count = math.max(1, math.min(16, n))
			save_settings()
			return true
		end
		return false

	-- ===== 默认总开关（改完同步到上面总开关）=====
	elseif k == 'def_master' then
		if is_select or is_left or is_right then
			settings.default_master = not settings.default_master
			settings.master = settings.default_master
			if not settings.master then clear_all() end
			save_settings()
			return true
		end
		return false

	-- ===== 默认镜像到（组合循环）=====
	elseif k == 'def_targets' then
		if is_left or is_right then
			local cur = settings.default_targets or { [1] = true }
			local combos = combos_for_avail({ 1, 2, 3 })
			local curcombo = {}
			for pi = 1, 3 do if cur[pi] then table.insert(curcombo, pi) end end
			local idx = 0
			for i, c in ipairs(combos) do
				if #c == #curcombo then
					local same = true
					for j = 1, #c do if c[j] ~= curcombo[j] then same = false; break end end
					if same then idx = i; break end
				end
			end
			if idx == 0 then idx = is_right and 1 or #combos
			else
				if is_right then idx = (idx % #combos) + 1
				else idx = ((idx - 2) % #combos) + 1 end
			end
			local ns = {}
			for _, pi in ipairs(combos[idx]) do ns[pi] = true end
			settings.default_targets = ns
			-- 清掉所有源的逐项覆盖，让它们跟随新默认目标
			settings.sources = {}
			save_settings()
			return true
		end
		return false

	-- ===== 默认按钮数量 =====
	elseif k == 'def_btn_count' then
		if is_left or is_right then
			local n = settings.default_button_count or 4
			if is_right then n = n + 1 else n = n - 1 end
			settings.default_button_count = math.max(1, math.min(16, n))
			settings.button_count = settings.default_button_count
			save_settings()
			return true
		end
		return false

	-- ===== 恢复默认 =====
	elseif k == 'apply_defaults' then
		if is_select then
			apply_defaults()
			return true
		end
		return false

	-- ===== 保存当前为默认模板 =====
	elseif k == 'save_as_default' then
		if is_select then
			save_current_as_default()
			return true
		end
		return false

	-- ===== 重置本 ROM 配置 =====
	elseif k == 'reset_rom' then
		if is_select then
			reset_rom_settings()
			return true
		end
		return false

	-- ===== v4.8 镜像源选择 =====
	elseif k == 'ui_src' then
		if is_left or is_right then
			-- 只在游戏里真实存在的玩家之间轮换（P1~P4）
			local exist = {}
			for s = 0, 3 do
				for _, e in ipairs(entries) do
					if e.fields[s] then table.insert(exist, s); break end
				end
			end
			if #exist == 0 then return false end
			local idx = 1
			for i, s in ipairs(exist) do
				if s == ui_src then idx = i; break end
			end
			if is_right then idx = (idx % #exist) + 1
			else idx = ((idx - 2) % #exist) + 1 end
			ui_src = exist[idx]
			return true
		end
		return false

	elseif k == 'src_enable' then
		if is_select or is_left or is_right then
			settings.src_enabled[ui_src] = not src_active(ui_src)
			save_settings()
			return true
		end
		return false

	-- ===== 多控按键（v4.8：源固定为 ui_src，目标在"所有组合"间循环）=====
	-- 语义简化：回车 / 左右键 都在「无 → P2 → P3 → P4 → P2+P3 → … → 全部」
	-- 这个序列里前进或后退。这样不需要区分"未配置"与"显式空表"，
	-- 也就避开了 entry_stored_dst 回落默认导致的"关不掉"问题。
	elseif k == 'mirror' then
		local e = nil
		for _, x in ipairs(entries) do
			if x.sem == a.sem then e = x; break end
		end
		if not e then return false end
		local src = a.src or ui_src

		if is_select or is_left or is_right then
			local avail = {}
			for pi = 1, 3 do
				if pi ~= src and e.fields[pi] then table.insert(avail, pi) end
			end
			if #avail == 0 then return false end

			-- 组合序列：空集在最前（= 该键不镜像），其余按人数少→多
			local combos = { {} }
			local rest = combos_for_avail(avail)
			for _, c in ipairs(rest) do table.insert(combos, c) end

			local ss = settings.sources[src]
			local cur = (type(ss) == 'table' and type(ss[e.sem]) == 'table') and ss[e.sem] or {}
			-- 把当前配置归一化成"有效玩家列表"（升序、去 src、去不存在字段）
			local cur_list = {}
			for _, pi in ipairs(avail) do
				if cur[pi] then table.insert(cur_list, pi) end
			end
			-- 定位当前组合在 combos 序列中的位置（combos[1] 是空集）
			local idx = 0
			for i, c in ipairs(combos) do
				if #c == #cur_list then
					local same = true
					for j = 1, #c do
						if c[j] ~= cur_list[j] then same = false; break end
					end
					if same then idx = i; break end
				end
			end
			if idx == 0 then idx = 1 end
			if is_left then
				idx = ((idx - 2) % #combos) + 1
			else
				idx = (idx % #combos) + 1
			end

			if type(settings.sources[src]) ~= 'table' then settings.sources[src] = {} end
			local ns = {}
			for _, pi in ipairs(combos[idx]) do ns[pi] = true end
			settings.sources[src][e.sem] = ns
			-- 只要开始配置就顺带启用该源，避免"配了但没开"的困惑
			if #combos[idx] > 0 then settings.src_enabled[src] = true end
			save_settings()
			return true
		end
		return false

	end

	return false
end

function copilot2p.startplugin()
	local home = manager.options.entries.homepath:value():match('([^;]+)')
	dir_path = home .. '/copilot2p'

	-- ★ v4.8.1 修复：dir_path 目录若不存在，所有 io.open(...,'w') 都会静默失败，
	--   表现为"状态文件不生成、配置保存不生效"。这里主动创建并用写入探针验证。
	--   lfs 由 plugins/boot.lua 预先 require，插件环境可直接使用。
	local ok_lfs, lfs_mod = pcall(require, 'lfs')
	if ok_lfs and lfs_mod then
		pcall(function() return lfs_mod.mkdir(dir_path) end)
	end

	-- 探针：真正写一个文件确认目录可写。UNC 路径下 lfs.attributes 可能不可靠，
	-- 只有实际写入成功才算可用；失败则把原因暴露到 last_error。
	local probe = dir_path .. '/.write_probe'
	local pf = io.open(probe, 'w')
	if pf then
		pf:write('ok'); pf:close()
		os.remove(probe)
	else
		last_error = 'dir not writable: ' .. tostring(dir_path)
		emu.print_error('[copilot2p] ' .. last_error)
	end

	prestart_subscription = emu.register_prestart(function()
		built = false
		entries = {}
		-- 每次启动新 ROM 都要重置缓存的 romname，否则同一 MAMEUI 会话
		-- 切换游戏时会继续读写上一个游戏的配置文件（ROM 隔离失效）
		rom_name = nil
		menu_verify = ''
		load_settings()
		write_status({ phase = 'prestart' })
	end)
	frame_subscription = emu.add_machine_frame_notifier(function()
		local ok, err = pcall(tick)
		if not ok then last_error = 'tick: ' .. tostring(err) end
	end)
	stop_subscription = emu.add_machine_stop_notifier(function()
		clear_all()
		save_settings()
		write_status({ phase = 'stopped' })
	end)

	emu.register_menu(menu_callback, menu_items, _p('plugin-copilot2p', '1P联动多玩家'))
end

return exports
