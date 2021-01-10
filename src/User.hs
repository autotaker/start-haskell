module User where

import Lens.Micro.Platform (makeLenses)
import RIO (Text)

data User = User
  { _username :: Username,
    _password :: Password -- 簡単のため平文パスワードとします。
  }
  deriving (Eq, Ord, Show)

type Username = Text

type Password = Text

makeLenses ''User