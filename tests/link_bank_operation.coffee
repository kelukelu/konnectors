fixtures = require 'cozy-fixtures'
should = require 'should'
moment = require 'moment'
americano = require 'americano-cozy'
log = require('printit')
    prefix: 'test link operation'

BankOperation = require '../server/models/bankoperation'
linkBankOperation = require '../server/lib/link_bank_operation'


PhoneBill = americano.getModel 'PhoneBill',
    date: Date
    vendor: String
    amount: Number
    fileId: String

loadFixtures = (callback) ->
    fixtures.load
        dirPath: './tests/fixtures/operations.json'
        doctypeTarget: 'BankOperation'
        silent: true
        removeBeforeLoad: true
        callback: ->
            fixtures.load
                dirPath: './tests/fixtures/files.json'
                doctypeTarget: 'File'
                silent: true
                removeBeforeLoad: true
                callback: ->
                    fixtures.load
                        dirPath: './tests/fixtures/bills.json'
                        doctypeTarget: 'PhoneBill'
                        silent: true
                        removeBeforeLoad: true
                        callback: callback


describe 'Running link_operation', ->

    operations = []
    linker = linkBankOperation
        log: log
        model: PhoneBill
        identifier: 'vendor01'
        dateDelta: 5
        amountDelta: 5

    before (done) ->
        @timeout 4000

        map = (doc) ->
            emit doc.date, doc
            return
        BankOperation.defineRequest 'byDate', map, ->
            PhoneBill.defineRequest 'byDate', map, done

    before (done) ->
                done()


    describe 'should link given bill to operation with', ->

        it 'same amount and same date', (done) ->

            @timeout 3000

            bills =
                fetched: [
                    date: moment '03/01/2015'
                    amount: '20.0'
                    vendor: 'vendor01'
                    fileId: 125
                ]

            loadFixtures ->
                linker {}, bills, {}, ->
                    BankOperation.all (err, operations) ->
                        operations.length.should.equal 2
                        should.exist operations[1].binary
                        operations[1].binary.file.id.should.equal "555"
                        done()

        it 'amount inside amount delta and same date', (done) ->

            @timeout 3000

            bills =
                fetched: [
                    date: moment '03/01/2015'
                    amount: '16.0'
                    vendor: 'vendor01'
                    fileId: 125
                ]

            loadFixtures ->
                linker {}, bills, {}, ->
                    BankOperation.all (err, operations) ->
                        operations.length.should.equal 2
                        should.exist operations[1].binary
                        operations[1].binary.file.id.should.equal "555"
                        done()

        it 'same amount and date in date delta', (done) ->

            @timeout 3000

            bills =
                fetched: [
                    date: moment '03/04/2015'
                    amount: '20.0'
                    vendor: 'vendor01'
                    fileId: 125
                ]

            loadFixtures ->
                linker {}, bills, {}, ->
                    BankOperation.all (err, operations) ->
                        operations.length.should.equal 2
                        should.exist operations[1].binary
                        operations[1].binary.file.id.should.equal "555"
                        done()

        it 'amount inside amount delta and date in date delta', (done) ->

            @timeout 3000

            bills =
                fetched: [
                    date: moment '03/05/2015'
                    amount: '16.0'
                    vendor: 'vendor01'
                    fileId: 125
                ]

            loadFixtures ->
                linker {}, bills, {}, ->
                    BankOperation.all (err, operations) ->
                        operations.length.should.equal 2
                        should.exist operations[1].binary
                        operations[1].binary.file.id.should.equal "555"
                        done()


    describe 'should not link given bill to operation with', ->

        it 'amount not in amount delta and same date', (done) ->

            @timeout 3000

            bills =
                fetched: [
                    date: moment '03/01/2015'
                    amount: '12.0'
                    vendor: 'vendor01'
                    fileId: 125
                ]

            loadFixtures ->
                linker {}, bills, {}, ->
                    BankOperation.all (err, operations) ->
                        operations.length.should.equal 2
                        should.not.exist operations[0].binary
                        should.not.exist operations[1].binary
                        done()


        it 'same amount and date not in date delta', (done) ->

            @timeout 3000

            bills =
                fetched: [
                    date: moment '03/21/2015'
                    amount: '20.0'
                    vendor: 'vendor01'
                    fileId: 125
                ]

            loadFixtures ->
                linker {}, bills, {}, ->
                    BankOperation.all (err, operations) ->
                        operations.length.should.equal 2
                        should.not.exist operations[0].binary
                        should.not.exist operations[1].binary
                        done()

        it 'same amount and same date without identifier', (done) ->

            @timeout 3000

            bills =
                fetched: [
                    date: moment '03/01/2015'
                    amount: '20.0'
                    vendor: 'vendor01'
                    fileId: 125
                ]

            linker = linkBankOperation
                log: log
                model: PhoneBill
                identifier: 'weirdvendor'
                dateDelta: 5
                amountDelta: 5

            loadFixtures ->
                linker {}, bills, {}, ->
                    BankOperation.all (err, operations) ->
                        operations.length.should.equal 2
                        should.not.exist operations[0].binary
                        should.not.exist operations[1].binary
                        done()


