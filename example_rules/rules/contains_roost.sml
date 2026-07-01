Import(
  rules=[
    'models/base.sml',
    'models/post.sml',
  ]
)

ContainsRoost = Rule(
  when_all=[
    EventType == '\'create_post\'',
    TextContains(text=PostText, phrase='roost'),
  ],
  description='post contains the word roost',
)

WhenRules(
  rules_any=[ContainsRoost],
  then=[
    LabelAdd(entity=UserId, label='meow'),
  ],
)
