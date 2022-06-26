module Evergreen.V674.Authentication exposing (..)

import Dict
import Evergreen.V674.Credentials
import Evergreen.V674.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V674.User.User
    , credentials : Evergreen.V674.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
