module Evergreen.V703.Compiler.DifferentialParser exposing (..)

import Evergreen.V703.Compiler.AbstractDifferentialParser
import Evergreen.V703.Compiler.Acc
import Evergreen.V703.Parser.Block
import Evergreen.V703.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V703.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V703.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V703.Parser.Block.ExpressionBlock) Evergreen.V703.Compiler.Acc.Accumulator
