Import(
  rules=[
    'models/base.sml',
    'models/post.sml',
  ]
)

ContainsDog = Rule(
  when_all=[
    EventType == '\'create_post\'',
    TextContains(text=PostText, phrase='dog'),
  ],
  description='Post contains the word dog',
)

WhenRules(
  rules_any=[ContainsDog],
  then=[
    LabelAdd(entity=UserId, label='meow'),
  ],
)
