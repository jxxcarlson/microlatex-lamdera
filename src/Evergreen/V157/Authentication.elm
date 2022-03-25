module Evergreen.V157.Authentication exposing (..)

import Dict
import Evergreen.V157.Credentials
import Evergreen.V157.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V157.User.User
    , credentials : Evergreen.V157.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
