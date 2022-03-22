module Evergreen.V149.Authentication exposing (..)

import Dict
import Evergreen.V149.Credentials
import Evergreen.V149.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V149.User.User
    , credentials : Evergreen.V149.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
