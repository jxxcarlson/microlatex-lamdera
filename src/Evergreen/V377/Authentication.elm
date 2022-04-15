module Evergreen.V377.Authentication exposing (..)

import Dict
import Evergreen.V377.Credentials
import Evergreen.V377.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V377.User.User
    , credentials : Evergreen.V377.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
