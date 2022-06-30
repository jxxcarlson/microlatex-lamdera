module Evergreen.V679.Authentication exposing (..)

import Dict
import Evergreen.V679.Credentials
import Evergreen.V679.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V679.User.User
    , credentials : Evergreen.V679.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
