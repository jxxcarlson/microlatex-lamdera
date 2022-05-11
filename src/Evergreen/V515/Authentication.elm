module Evergreen.V515.Authentication exposing (..)

import Dict
import Evergreen.V515.Credentials
import Evergreen.V515.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V515.User.User
    , credentials : Evergreen.V515.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
