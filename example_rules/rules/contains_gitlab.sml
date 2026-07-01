Import(
  rules=[
    'models/base.sml',
    'models/post.sml',
  ]
)

ContainsGitlab = Rule(
  when_all=[
    EventType == '\'create_post\'',
    TextContains(text=PostText, phrase='gitlab'),
  ],
  description='posts with the word gitlab',
)

WhenRules(
  rules_any=[ContainsGitlab],
  then=[
    LabelAdd(entity=UserId, label='meow'),
  ],
)
