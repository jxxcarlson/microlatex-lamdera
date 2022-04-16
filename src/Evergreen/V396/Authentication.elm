module Evergreen.V396.Authentication exposing (..)

import Dict
import Evergreen.V396.Credentials
import Evergreen.V396.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V396.User.User
    , credentials : Evergreen.V396.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
