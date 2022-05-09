module Evergreen.V503.Authentication exposing (..)

import Dict
import Evergreen.V503.Credentials
import Evergreen.V503.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V503.User.User
    , credentials : Evergreen.V503.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
