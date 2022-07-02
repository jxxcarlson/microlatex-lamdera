module Evergreen.V683.Authentication exposing (..)

import Dict
import Evergreen.V683.Credentials
import Evergreen.V683.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V683.User.User
    , credentials : Evergreen.V683.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
