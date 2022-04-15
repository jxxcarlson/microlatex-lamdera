module Evergreen.V378.Authentication exposing (..)

import Dict
import Evergreen.V378.Credentials
import Evergreen.V378.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V378.User.User
    , credentials : Evergreen.V378.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
