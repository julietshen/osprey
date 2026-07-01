Import(
  rules=[
    'models/base.sml',
    'models/post.sml',
  ]
)

ContainsTangle = Rule(
  when_all=[
    EventType == 'create_post',
    TextContains(text=PostText, phrase='tangle'),
  ],
  description='post contains the word tangle',
)

WhenRules(
  rules_any=[ContainsTangle],
  then=[
    LabelAdd(entity=UserId, label='meow'),
  ],
)
