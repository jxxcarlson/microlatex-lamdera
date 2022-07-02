module Evergreen.V690.Authentication exposing (..)

import Dict
import Evergreen.V690.Credentials
import Evergreen.V690.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V690.User.User
    , credentials : Evergreen.V690.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
