module Evergreen.V353.Compiler.DifferentialParser exposing (..)

import Evergreen.V353.Compiler.AbstractDifferentialParser
import Evergreen.V353.Compiler.Acc
import Evergreen.V353.Parser.Block
import Evergreen.V353.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V353.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V353.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V353.Parser.Block.ExpressionBlock) Evergreen.V353.Compiler.Acc.Accumulator
