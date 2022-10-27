# **L4D2 AnneHappy Rework Update log**
# **L4D2 AnneHappy Rework 更新记录**

## **更新记录:**

### ** 2022年11月更新记录**
#### 前言
新插件包的目的是为了更快的获取上游更新，降低我的维护成本，当第一版本插件完成后，我的更新就只需要更新特感等功能性插件
其他的插件来源于上游的更新，可以更专注于**摸鱼**
社区插件的更新能够得到马上的同步
#### 插件更新记录
- ai_tank2.sp 增加了梯子检测功能，并且删除了tank后退动作的连跳处理，修复了tank可能会纵云梯大跳的问题
- ai_jockey_new.sp 修复了猴子被推后马上就能通过使用跳跃功能来恢复重新使用技能导致的问题
- infected_control.smx 将5种模式的4种刷特合并为1个插件处理，
					   适配目标选择插件，选择生还者构建刷特坐标系的时候不能选目标已满的玩家
					   特感的生成顺序改为由队列进行处理，解决一波可能刷同样的特感[主要是boomer和spitter]的问题
					   原来的射线刷特方法取消，改为获取"logic_script"的值来判断[也还是射线处理，但是效率比原来快，而且效果更好]
					   检测env_physics_blocker的阻拦属性，原来不能生成的地方现在很大可能也能生成了
					   射线类型改变，由MASK_NPCSOLID_BRUSHONLY类型更改为MASK_PLAYERSOLID，能最大程度上增加可刷特位置
					   修复原来刷特IsPlayerStuck的射线过滤器的bug，会导致新版插件把射线改为MASK_PLAYERSOLID后导致的卡在新加的物件上
					   倒地玩家的视线不会影响特感的传送(相当于倒地生还视线不如狗）
					   增加最大刷特距离的控制
- server.smx 分开为2个插件join.smx 和 server.smx，其中join.smx主要处理加入游戏后换队的问题，server.smx处理Anne等模式下特殊的一些功能
- l4d_target_override.smx 升级为最新版本，增加了targeted功能，能限制生还者被选为目标的数量
- SI_Target_limit.smx 目标选择插件适配新版l4d_target_override插件，自动控制控制型特感选相同生还者为目标的数量
- vote.smx 投票cfg插件增加cvar来控制投票文件
- l4d2_Anne_stuck_tank_teleport.smx 救援关不启用跑男惩罚
- text.smx插件会进行Cvar的检测，一次来避免插件加载顺序导致的无法启动的问题
- rpg.smx 增加皮肤功能，且增加自动检测依赖启用不同功能的能力,修复关闭帽子无法保存到数据库的问题
- specrates, hextags, rpg, l4d_hats,l4d2_item_hint.smx ,veterans增加检测积分插件的功能，没有积分插件也不影响使用
- l4d2_weapon_attributes.smx 增加霰弹枪装填速度的Cvar控制，需要WeaponHandling作为前置插件(加载顺序无影响)
- 对抗插件全部更新最新版本，部分插件改用i18n汉化，英语汉语翻译都有(具体汉化插件和i18n汉化请看项目)
- AnneHappy、AnneHappyPlus枪械uzi削弱
当前版本武器伤害具体如下
[AnneHappy](https://github.com/fantasylidong/CompetitiveWithAnne/blob/master/cfg/vote/weapon/AnneHappy.cfg)
[AnneHappyPlus](https://github.com/fantasylidong/CompetitiveWithAnne/blob/master/cfg/vote/weapon/AnneHappyPlus.cfg)
[ZoneMod](https://github.com/fantasylidong/CompetitiveWithAnne/blob/master/cfg/vote/weapon/zonemod.cfg)

#### 一些重要特感和生还数据：
生还者速度：220
坦克速度： 225
坦克连跳加速度： 60
坦克停止距离： 135
坦克近战攻击距离： 75
小僵尸数量：z_common_limit 24 (大于原AnneHappy的21只，小于zonemod的30只）
被胖子喷产生的小僵尸数量： 1个 13 2个 25 3个35 4个45
尸潮发生时同时存在的小僵尸数量： 45 （大于原AnneHappy的50只，小于zonemod的50只）
其他不太重要数据请在对应模式的shared_cvars.cfg文件
特感增强的数据在对应模式的shared_settings.cfg文件

#### 性能问题
当前刷特版本不多人运动情况下，开20T服务器依旧在90帧以上，最小帧1%也在60帧以上
但是一旦超过4人，20T根本就无法稳定了，8人运动基本在12~14T能基本在90帧以上，最小帧1%在50以上
以上性能测试为r5 3900x 测试，云服高特情况可能还要打个7折起步
综上，正常情况下刷特应该已经不成为性能瓶颈，6人运动腾讯轻量云服12t基本达到瓶颈（预估）

#### 结论
目前版本的难度还是相当大的，4特带一个新手的压力都不小，5特带一个新手难度就比较大了，6特带一个新手不靠卡克基本很难通过c2
所以建议新手玩家多玩玩4，5特之后再去6特混野
各个服主也可以根据自己喜好设置不同的难度，大部分的都可以通过控制Cvar来控制难度
部分可能需要源码的，所有源码也已经开源，其中AnneHappy为主的插件在scripts/AnneHappy/文件夹
拓展性为主的插件在scripts/extend/文件夹
如果发现有问题，请