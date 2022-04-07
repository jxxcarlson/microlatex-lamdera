module Evergreen.V279.Authentication exposing (..)

import Dict
import Evergreen.V279.Credentials
import Evergreen.V279.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V279.User.User
    , credentials : Evergreen.V279.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
