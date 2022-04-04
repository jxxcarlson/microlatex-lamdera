module Evergreen.V234.Authentication exposing (..)

import Dict
import Evergreen.V234.Credentials
import Evergreen.V234.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V234.User.User
    , credentials : Evergreen.V234.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
