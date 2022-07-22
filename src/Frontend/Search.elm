module Frontend.Search exposing (search)

import Effect.Lamdera
import Types exposing (DocumentHandling(..), DocumentList(..))


search model =
    ( { model
        | actualSearchKey = model.inputSearchKey
        , documentList = StandardList
        , currentMasterDocument = Nothing
      }
    , Effect.Lamdera.sendToBackend (Types.SearchForDocuments StandardHandling model.currentUser model.inputSearchKey)
    )
