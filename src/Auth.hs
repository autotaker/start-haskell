module Auth where

import Lens.Micro.Platform (Lens', makeLenses)
import RIO (RIO)
import User (Password, User (User), Username)

data UserRepository env = UserRepository
  { _findByUsername :: Username -> RIO env (Maybe User),
    _createUser :: User -> RIO env ()
  }

makeLenses ''UserRepository

class HasUserRepository env where
  userRepositoryL :: Lens' env (UserRepository env)

signin :: (HasUserRepository env) => Username -> Password -> RIO env (Maybe User)
signin usernm passwd = pure $ Just (User usernm passwd)

signup :: (HasUserRepository env) => Username -> Password -> RIO env (Maybe User)
signup = error "Let's implement"