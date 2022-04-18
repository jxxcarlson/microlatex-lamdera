module Evergreen.V405.Authentication exposing (..)

import Dict
import Evergreen.V405.Credentials
import Evergreen.V405.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V405.User.User
    , credentials : Evergreen.V405.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
