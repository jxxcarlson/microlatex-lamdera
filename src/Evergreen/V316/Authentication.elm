module Evergreen.V316.Authentication exposing (..)

import Dict
import Evergreen.V316.Credentials
import Evergreen.V316.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V316.User.User
    , credentials : Evergreen.V316.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
