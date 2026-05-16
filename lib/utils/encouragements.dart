import 'dart:math';

final Random _rng = Random();

// ── Compound interest (复利) ──
final List<String> _compoundInterest = [
  '复利是世界第八大奇迹 —— 爱因斯坦 🧠',
  '每天存一点，复利会帮你把雪球滚大 ❄️',
  '复利的奇迹：每天进步1%，一年后是37倍 📈',
  '现在存的每一分钱，都在为复利打工 💼',
  '时间是复利最好的朋友，越早开始越受益 ⏰',
  '复利不只适用于金钱，知识、健康、习惯都是 🌱',
  '微小的坚持 × 时间 = 惊人的结果 ✨',
  '复利三要素：本金、时间、收益率，你都有了 ✅',
  '不要低估复利的力量，也不要高估短期的效果 🎯',
  '每月多存500块，30年后复利就是一笔巨款 💰',
  '复利的本质：让钱替你打工 🏦',
  '今天的储蓄是明天的复利种子 🌰',
  '复利不会辜负每一个坚持存钱的人 🏆',
  '10%的年化收益，7.2年本金翻倍 —— 72法则 📊',
  '复利最大的敌人是消费主义，最大的朋友是时间 ⚔️',
  '你的每一笔存款都是复利大军的士兵 🪖',
  '复利思维：做难而正确的事，剩下的交给时间 ⏳',
  '用复利的眼光看消费：今天省下的，30年后值多少？🤔',
  '复利像滚雪球，关键是找到湿的雪和长长的坡 🏔️',
  '复利的核心不是快，而是不停 🚶',
  '每天进步一点点，复利终将带来质变 🦋',
  '钱生钱，利滚利，这就是复利的魔法 ✨',
  '种一棵树最好的时间是十年前，存一笔钱也是 🌳',
  '复利告诉你：坚持比金额更重要 💪',
  '收入到账！这笔钱即将加入你的复利大军 🚀',
  '每一次存入，都是在给未来的复利雪球加雪 ❄️',
  '复利不看你一次存多少，看你坚持了多久 📏',
  '当复利开始起作用，你的财富会像坐了火箭 🚀',
  '复利的魔力：最初看不见，后来来不及 👀',
  '让每一分钱都成为你的员工，24小时为你工作 🏢',
  '今天不存钱，明天就没有复利的资格 🚫',
  '复利的前提是：你得先存下钱 🎯',
  '赚到的钱存下一半，复利自然会帮你创造奇迹 🌟',
  '复利不挑人，只挑时间 —— 越早开始越幸运 🍀',
  '坚持定投，复利微笑曲线会给你惊喜 😊',
  '坚持定投，复利微笑曲线会给你惊喜 😊',
  '每一次克制消费，都是在为复利蓄力 ⚡',
  '复利是长期主义者的奖励 🎁',
  '不要打断复利 —— 持续存，不要停 🔄',
  '复利的敌人是中断，朋友是坚持 🤝',
];

// ── Saving & frugality ──
final List<String> _quotes = [
  '今日省一毫，明日多一分 💪',
  '少喝一杯奶茶，多攒一份底气 ☕',
  '今天的克制，是明天的自由 ✨',
  '省钱不是目的，过自己想要的生活才是 🎯',
  '每一分钱都值得被认真对待 💎',
  '存钱就像种树，最好的时间是十年前，其次是现在 🌱',
  '不乱花钱的人，运气都不会太差 🍀',
  '省下的每一块钱，都是在给自己的未来投票 🗳️',
  '消费带来短暂快乐，存款带来长久安心 😌',
  '你的存款，是你对抗世界的底气 💪',
  '今天忍住不买，明天就能买更好的 🎁',
  '控制欲望的人，终将被生活奖励 🏆',
  '不是东西买不起，而是存款更有性价比 💰',
  '当你开始存钱，你会发现原来生活不需要那么多 🧘',
  '延迟满足，是成年人最顶级的自律 ⏳',
  '消费降级，生活质量不降级 ✨',
  '少买没用的，多攒有用的 🎒',
  '每一次自律，都是对未来的投资 🌱',
  '真正的自由不是想买就买，而是不想买就可以不买 🌟',
  '存钱不是苦行，而是对自己未来的温柔 🫂',
  '财务健康的秘诀：收入大于支出，就这么简单 📊',
];

// ── Income & progress ──
final List<String> _incomeQuotes = [
  '收入到账！离目标又近了一步 🚀',
  '赚钱不容易，珍惜每一分劳动成果 💡',
  '很棒！你对钱包的掌控力越来越强了 📊',
  '每一笔收入都是努力的见证 🌟',
  '管好钱的人，才能管好人生 🌈',
  '你的坚持，时间看得见 ⏰',
  '今天的记录，是明天财富的地图 🗺️',
  '积少成多，聚沙成塔 🏖️',
  '好的开始是成功的一半，你已经在路上了 👍',
  '自律的人，生活都会悄悄奖励他 🎁',
  '对自己负责，从管好每一分钱开始 ✅',
  '存钱会上瘾，越存越想存 🎯',
  '现在的每一笔记录，都是未来感谢自己的理由 📝',
  '你认真生活的样子，真好看 🌸',
  '管理金钱，就是管理人生 🌟',
  '对自己诚实，对金钱认真 💎',
  '理性消费不是吝啬，而是智慧 🧠',
  '想要自由，先学会自律 🔑',
  '记账不是限制你花钱，而是帮你花对钱 💡',
  '花钱是本能，存钱是本事 👍',
  '省下的就是赚到的 🔄',
  '不想被生活选择，就要有足够的选择权 🎫',
  '今天能省则省，明天才有底气做梦 🌙',
  '你每存下一块钱，就是在为梦想添砖加瓦 🧱',
  '对未来的自己好一点，今天多存一点 🤝',
];

// ── Expense awareness ──
final List<String> _expenseQuotes = [
  '这笔不花也不会怎样，对吧？😉',
  '先存钱，再花钱，顺序别搞反了 🔄',
  '问问自己：这是需要，还是想要？🤔',
  '冷静一下再做决定，你会感谢自己的理智 ⏱️',
  '看到喜欢的先加购物车，明天再来看 🛒',
  '不买立省百分百 ✅',
  '你的未来会感谢现在克制的自己 🤝',
  '降低物欲，提升幸福感 🧘‍♀️',
  '拥有的越少，内心越富足 🍃',
  '极简不是没有，而是够了就好 ☯️',
  '存钱最简单的方法：少花 ✂️',
  '把每一次想花钱的冲动，变成存钱的动力 💪',
  '理智消费是成年人的必修课 📚',
  '花钱前三秒停一下，问自己真的需要吗 ⏸️',
  '不为情绪买单，只为价值付费 🎫',
  '量入为出，是生活最好的状态 ⚖️',
  '每一次理性消费，都是对自己负责 ✅',
  '美好的生活不在于拥有多少，而在于需要多少 🍃',
  '少花不必要的，多攒未来需要的 🎯',
];

// ── English versions ──

final List<String> _enCompoundInterest = [
  'Compound interest is the 8th wonder of the world — Einstein',
  'Save a little each day, compound interest rolls the snowball',
  'The miracle of compounding: improve 1% daily, 37x in a year',
  'Every cent you save works for you in compound interest',
  'Time is compound interest\'s best friend — start early',
  'Compound interest isn\'t just for money — knowledge, health, habits too',
  'Small consistency × time = astonishing results',
  'Three keys: principal, time, rate — you\'ve got them all',
  'Don\'t underestimate compounding, don\'t overestimate short-term gains',
  'Save ¥500 more each month, 30 years of compounding = a fortune',
  'Compound interest: let your money work for you',
  'Today\'s savings are tomorrow\'s compound seeds',
  'Compound interest rewards every consistent saver',
  '10% annual return = 7.2 years to double — Rule of 72',
  'Compound interest\'s biggest enemy is consumerism, best friend is time',
  'Think in compound interest: what\'s that purchase worth in 30 years?',
  'Compounding is like rolling a snowball — find wet snow and a long hill',
  'The core of compounding isn\'t speed — it\'s never stopping',
  'Money makes money, and the money money makes makes more money',
  'The best time to plant a tree was 10 years ago — saving too',
  'Compounding teaches: consistency matters more than amount',
  'Income received! This money joins your compound army',
  'Every deposit adds snow to your future compound snowball',
  'Compounding doesn\'t care how much you save once — it cares how long',
  'When compounding kicks in, your wealth rides a rocket',
  'Compound magic: invisible at first, unstoppable later',
  'Make every cent your employee, working 24/7 for you',
  'Don\'t interrupt compounding — keep saving, don\'t stop',
  'Compounding is the reward for long-term thinkers',
];

final List<String> _enQuotes = [
  'Save a little today, gain a lot tomorrow',
  'Skip one bubble tea, build one more layer of security',
  'Today\'s restraint is tomorrow\'s freedom',
  'Saving isn\'t the goal — living the life you want is',
  'Every cent deserves to be taken seriously',
  'Saving is like planting trees — best time was 10 years ago, second best is now',
  'People who don\'t waste money rarely have bad luck',
  'Every dollar saved is a vote for your future',
  'Spending brings short joy, savings bring long peace',
  'Your savings are your shield against the world',
  'Resist buying today, buy something better tomorrow',
  'Control your desires, and life will reward you',
  'It\'s not that you can\'t afford it — savings have better ROI',
  'When you start saving, you realize you don\'t need that much',
  'Delayed gratification is the ultimate adult discipline',
  'Cut spending without cutting quality of life',
  'Buy less useless stuff, save more useful money',
  'Every act of discipline is an investment in your future',
  'True freedom isn\'t buying anything you want — it\'s not needing to',
  'Saving isn\'t suffering — it\'s kindness to your future self',
  'Financial health secret: earn more than you spend. That\'s it.',
];

final List<String> _enIncomeQuotes = [
  'Income received! One step closer to your goal',
  'Money isn\'t easy — cherish every cent you earn',
  'Great! Your grip on your wallet keeps getting stronger',
  'Every income is proof of your hard work',
  'People who manage money well, manage life well',
  'Your persistence is visible — time tells',
  'Today\'s records are tomorrow\'s wealth map',
  'Many a mickle makes a muckle',
  'Well begun is half done — you\'re already on your way',
  'Life quietly rewards the disciplined',
  'Being responsible starts with managing every cent',
  'Saving is addictive — the more you save, the more you want to',
  'Every record today is a future thank-you note from yourself',
  'You managing your money — that\'s a beautiful sight',
  'Managing money is managing life',
  'Be honest with yourself and serious about your money',
  'Rational spending isn\'t stingy — it\'s wisdom',
  'Want freedom? First learn discipline',
  'Tracking isn\'t to limit spending — it\'s to spend right',
  'Spending is instinct, saving is skill',
  'What you save equals what you earn',
  'Don\'t let life choose you — earn the right to choose',
];

final List<String> _enExpenseQuotes = [
  'You won\'t miss this purchase, right?',
  'Save first, spend later — don\'t get the order wrong',
  'Ask yourself: need or want?',
  'Cool down before deciding — future you will thank you',
  'Add to cart, check tomorrow',
  'Not buying saves 100%',
  'Your future self will thank your current restraint',
  'Lower desires, higher happiness',
  'Own less, feel more',
  'Minimalism isn\'t having nothing — it\'s having enough',
  'Simplest way to save: spend less',
  'Turn every urge to spend into motivation to save',
  'Mindful spending is an adult必修课 (required course)',
  'Pause 3 seconds before buying — do you really need it?',
  'Pay for value, not for emotions',
  'Live within your means — life\'s best balance',
  'Every rational purchase is being responsible for yourself',
  'A good life isn\'t about how much you own — it\'s about how much you need',
  'Skip the unnecessary, save for what matters',
];

/// Returns a random encouragement, weighted by [type].
///
/// - 'income': high chance (~55%) of compound interest quotes
/// - 'expense': occasional (~20%) compound interest, mostly expense awareness
/// - 'saving' / null: balanced mix
/// [lang] is 'zh' or 'en' for localized quotes.
String getWeightedEncouragement(String type, {String lang = 'zh'}) {
  final compound = lang == 'en' ? _enCompoundInterest : _compoundInterest;
  final quotes = lang == 'en' ? _enQuotes : _quotes;
  final incomeQuotes = lang == 'en' ? _enIncomeQuotes : _incomeQuotes;
  final expenseQuotes = lang == 'en' ? _enExpenseQuotes : _expenseQuotes;

  if (type == 'income') {
    final r = _rng.nextDouble();
    if (r < 0.55) {
      return compound[_rng.nextInt(compound.length)];
    } else if (r < 0.90) {
      return incomeQuotes[_rng.nextInt(incomeQuotes.length)];
    } else {
      return quotes[_rng.nextInt(quotes.length)];
    }
  } else if (type == 'expense') {
    final r = _rng.nextDouble();
    if (r < 0.20) {
      return compound[_rng.nextInt(compound.length)];
    } else if (r < 0.80) {
      return expenseQuotes[_rng.nextInt(expenseQuotes.length)];
    } else {
      return quotes[_rng.nextInt(quotes.length)];
    }
  } else {
    final all = [
      ...compound,
      ...quotes,
      ...incomeQuotes,
      ...expenseQuotes,
    ];
    return all[_rng.nextInt(all.length)];
  }
}
