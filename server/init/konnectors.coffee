path = require 'path'
fs = require 'fs'
async = require 'async'
log = require('printit')
    prefix: null
    date: true

Konnector = require '../models/konnector'
konnectorModules = require '../lib/konnector_hash'

module.exports = (callback) ->
    Konnector.all (err, konnectors) ->
        if err
            log.error err
            callback err
        else
            konnectorHash = {}
            for konnector in konnectors
                konnectorHash[konnector.slug] = konnector
                # Reset isImporting state to false if value is true
                # This happens when the app is crashing while importing
                if konnector.isImporting is true
                    konnector.isImporting = false
                    konnector.save (err) ->
                        if err
                            log.debug "#{konnector.slug} | #{err}"
                        else
                            log.debug "#{konnector.slug}: reseting isImporting"

            konnectorsToCreate = []

            for name, konnectorModule of konnectorModules
                unless konnectorHash[konnectorModule.slug]?
                    konnectorsToCreate.push konnectorModule

            async.eachSeries konnectorsToCreate, (konnector, callback) ->
                konnector.init (err) ->
                    if err
                        log.error err
                        callback err
                    else
                        Konnector.create konnector, (err) ->
                            log.error err if err
                            callback err
            , (err) ->
                log.info 'All konnectors created'
                callback err if callback?
