module Auth where

import Control.Method (invoke)
import Control.Monad.Trans.Maybe (MaybeT (MaybeT, runMaybeT))
import Lens.Micro.Platform (Lens', makeLenses)
import RIO (MonadTrans (lift), RIO, guard, isNothing, (^.))
import User (Password, User (User), Username, password)

data UserRepository env = UserRepository
  { _findByUsername :: Username -> RIO env (Maybe User),
    _createUser :: User -> RIO env ()
  }

makeLenses ''UserRepository

newtype PasswordGenerator env = PasswordGenerator
  {_generate :: Int -> RIO env Password}

makeLenses ''PasswordGenerator

class HasUserRepository env where
  userRepositoryL :: Lens' env (UserRepository env)

class HasPasswordGenerator env where
  passwordGeneratorL :: Lens' env (PasswordGenerator env)

signin :: (HasUserRepository env) => Username -> Password -> RIO env (Maybe User)
signin usernm passwd = runMaybeT $ do
  user <- MaybeT $ invoke (userRepositoryL . findByUsername) usernm
  guard $ (user ^. password) == passwd
  pure user

signup :: (HasUserRepository env, HasPasswordGenerator env) => Username -> Password -> RIO env (Maybe User)
signup usernm passwd = runMaybeT $ do
  let user = User usernm passwd
  mUser <- lift $ invoke (userRepositoryL . findByUsername) usernm
  guard $ isNothing mUser
  lift $ invoke (userRepositoryL . createUser) user
  pure user