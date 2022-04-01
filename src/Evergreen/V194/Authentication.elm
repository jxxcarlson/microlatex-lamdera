module Evergreen.V194.Authentication exposing (..)

import Dict
import Evergreen.V194.Credentials
import Evergreen.V194.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V194.User.User
    , credentials : Evergreen.V194.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
