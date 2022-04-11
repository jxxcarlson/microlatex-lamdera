module Evergreen.V352.Authentication exposing (..)

import Dict
import Evergreen.V352.Credentials
import Evergreen.V352.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V352.User.User
    , credentials : Evergreen.V352.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
