进展简要汇报：
- 我确认了你当前配置里还在用 programs.opencode.enable / programs.opencode.settings（home/home.nix），但这些选项在最新模块里已被移除，所以 opencode.json 不会再生成。
- oh-my-opencode.json 仍会生成（取决于 programs.opencode.oh-my-opencode.enable），当前内容只有 google_auth = true。
- 我查了官方文档：OpenCode 全局配置应该是 ~/.config/opencode/opencode.json（支持 JSON/JSONC + $schema），插件通过 plugin = ["oh-my-opencode"] 加载；Oh‑My‑OpenCode 配置在 ~/.config/opencode/oh-my-opencode.json(.jsonc)，也有专用 $schema。
我建议的 best practice（可迁移复用、Nix 管理）：
1. 恢复/补齐全局 opencode.json  
   - 只放最小必要配置：$schema + plugin = ["oh-my-opencode"]  
   - 这样跨机器复用，也能保证插件一定被加载。
2. 保留 oh-my-opencode.json(c)  
   - 只放你明确需要的配置（现在就是 google_auth = true），并加上 $schema。  
   - 其他复杂配置保持默认（文档也强调：没需求别乱改）。
3. 用 Nix 模块统一生成两个文件  
   - opencode.json 作为主配置  
   - oh-my-opencode.json 作为插件配置  
   - 用 mkDefault 保持可覆盖、可复用
在动手写 Nix 之前，需要你确认两个选择：
1. Google Auth 走哪条？  
   - A：内置 google_auth = true（简单）  
   - B：用 opencode-antigravity-auth 插件（更强，但要额外配置模型）
2. 只做最小配置，还是加一点常用设置？  
   - 最小配置：只写 plugin + google_auth  
   - 增强配置：比如主题、默认模型、权限等
你选个方向，我就直接改你的 Nix 配置。

nvim: bufferline、trouble 诊断面板、todo-comments、project.nvim）