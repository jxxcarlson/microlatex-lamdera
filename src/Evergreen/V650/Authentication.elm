module Evergreen.V650.Authentication exposing (..)

import Dict
import Evergreen.V650.Credentials
import Evergreen.V650.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V650.User.User
    , credentials : Evergreen.V650.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
