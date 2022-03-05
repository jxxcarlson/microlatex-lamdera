module Evergreen.V72.Authentication exposing (..)

import Dict
import Evergreen.V72.Credentials
import Evergreen.V72.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V72.User.User
    , credentials : Evergreen.V72.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
