module Evergreen.V103.Authentication exposing (..)

import Dict
import Evergreen.V103.Credentials
import Evergreen.V103.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V103.User.User
    , credentials : Evergreen.V103.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
