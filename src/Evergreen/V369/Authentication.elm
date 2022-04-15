module Evergreen.V369.Authentication exposing (..)

import Dict
import Evergreen.V369.Credentials
import Evergreen.V369.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V369.User.User
    , credentials : Evergreen.V369.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
