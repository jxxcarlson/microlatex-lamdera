module Evergreen.V342.Authentication exposing (..)

import Dict
import Evergreen.V342.Credentials
import Evergreen.V342.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V342.User.User
    , credentials : Evergreen.V342.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
