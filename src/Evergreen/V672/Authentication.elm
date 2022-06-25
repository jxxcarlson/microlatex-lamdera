module Evergreen.V672.Authentication exposing (..)

import Dict
import Evergreen.V672.Credentials
import Evergreen.V672.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V672.User.User
    , credentials : Evergreen.V672.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
