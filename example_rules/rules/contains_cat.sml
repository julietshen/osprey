Import(
  rules=[
    'models/base.sml',
    'models/post.sml',
  ]
)

ContainsCat = Rule(
  when_all=[
    TextContains(text=PostText, phrase='cat'),
    EventType == '\'create_post\'',
  ],
  description='looks for the word \'cat\' in the text of a post',
)

WhenRules(
  rules_any=[ContainsCat],
  then=[
    LabelAdd(entity=UserId, label='meow'),
  ],
)
