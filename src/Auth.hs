module Auth where

import User (Password, User, Username)

signin :: Username -> Password -> IO (Maybe User)
signin = error "Let's implement"

signup :: Username -> Password -> IO (Maybe User)
signup = error "Let's implement"