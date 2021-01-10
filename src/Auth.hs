module Auth where

import Control.Monad.Trans.Maybe (MaybeT (MaybeT, runMaybeT))
import Lens.Micro.Platform (Lens', makeLenses)
import RIO (RIO, guard, view, (^.))
import User (Password, User, Username, password)

data UserRepository env = UserRepository
  { _findByUsername :: Username -> RIO env (Maybe User),
    _createUser :: User -> RIO env ()
  }

makeLenses ''UserRepository

class HasUserRepository env where
  userRepositoryL :: Lens' env (UserRepository env)

signin :: (HasUserRepository env) => Username -> Password -> RIO env (Maybe User)
signin usernm passwd = runMaybeT $ do
  method <- view (userRepositoryL . findByUsername)
  user <- MaybeT $ method usernm
  guard $ (user ^. password) == passwd
  pure user

signup :: (HasUserRepository env) => Username -> Password -> RIO env (Maybe User)
signup = error "Let's implement"