# 🏸 羽毛球赛程与记分系统（Badminton Manager）

Go + Vue 3 实现的羽毛球比赛赛程管理与实时记分应用，单容器部署，数据落盘持久化。

## 功能

- **选手管理**：添加 / 删除选手，支持批量导入（按姓名去重，自动跳过已存在选手）
- **赛事管理**：单打 / 双打循环赛，支持一局定胜负、三局两胜、五局三胜，每局 11 / 15 / 21 分可选
- **分区与自动晋级**：赛事可分 2 / 4 个区（蛇形分配），每组打循环赛；分组赛全部结束后**自动生成半决赛**（A组第1 vs B组第2、B组第1 vs A组第2；不分区则 1v4、2v3），半决赛结束后**自动生成决赛 + 季军赛**，最终决出**冠军 / 亚军 / 季军 / 殿军**
- **积分榜**：每组实时排名，排序规则为胜场 → 净胜局 → 净胜分，出线名额绿色高亮
- **数据持久化**：状态保存在 `/data/data.json`，容器重启不丢失

## 快速开始（Docker）

```bash
docker compose up -d --build
```

浏览器打开 http://localhost:9988 即可。

### 换端口

修改 `docker-compose.yml` 中 ports 映射，例如 `"9090:8080"`。

## 本地开发（不用 Docker）

```bash
# 1. 启动后端（默认 :9988）
cd server
go run .

# 2. 启动前端 dev server（默认 :5173，已配置 /api 代理到 8080）
cd ../web
npm install
npm run dev
```

## API 一览

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/players` | 选手列表 |
| POST | `/api/players` | `{name}` 添加选手 |
| DELETE | `/api/players/{id}` | 删除选手 |
| GET | `/api/tournaments` | 赛事列表 |
| POST | `/api/tournaments` | `{name, mode: singles\|doubles, bestOf: 1\|3\|5, pointsPerGame: 11\|15\|21, groups: 1\|2\|4, playerIds[]}` 创建赛事 |
| GET | `/api/tournaments/{id}` | 赛事详情（含阶段 stage） |
| GET | `/api/tournaments/{id}/ranking` | 分组积分榜 |
| GET | `/api/tournaments/{id}/result` | 最终名次（未决出时为 null） |
| DELETE | `/api/tournaments/{id}` | 删除赛事及其比赛 |
| POST | `/api/tournaments/{id}/schedule` | `{courts}` 生成循环赛赛程 |
| GET | `/api/tournaments/{id}/matches` | 该赛事所有比赛 |
| GET | `/api/matches/{id}` | 比赛详情（含比分、状态、canUndo） |
| POST | `/api/matches/{id}/score` | `{side: "A"\|"B"}` 记一分；`{action: "undo"}` 撤销 |
| POST | `/api/matches/{id}/reset` | 重置本场比分 |

## 项目结构

```
badminton-manager/
├── Dockerfile              # 多阶段构建：Vue 构建 → Go 编译 → alpine 运行
├── docker-compose.yml
├── server/                 # Go 后端（零第三方依赖）
│   ├── main.go             # 入口、静态文件托管、SPA fallback
│   ├── handlers.go         # REST API 路由
│   ├── schedule.go         # 循环赛排程（圆圈法 / 双打组合贪心排轮）
│   ├── scoring.go          # 21 分制记分规则 + 撤销
│   └── store.go            # JSON 文件持久化
└── web/                    # Vue 3 + Vite 前端
    └── src/views/
        ├── PlayersView.vue      # 选手管理
        ├── TournamentsView.vue  # 赛事创建与管理
        ├── ScheduleView.vue     # 赛程表（按轮次分组）
        └── ScoreView.vue        # 实时记分牌
```
