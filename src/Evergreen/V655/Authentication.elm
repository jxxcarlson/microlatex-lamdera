module Evergreen.V655.Authentication exposing (..)

import Dict
import Evergreen.V655.Credentials
import Evergreen.V655.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V655.User.User
    , credentials : Evergreen.V655.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
