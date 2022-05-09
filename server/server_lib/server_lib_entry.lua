function GetAllOilrigsFromDatabase()
     MySQL.Async.fetchAll('SELECT * FROM oilrig_position', {}, function(oilrigs)
          Oilrigs = oilrigs
          Gotrigs = true
     end)
end

function GetUpdatedValue(oilrig_hash)
     MySQL.Async.fetch('SELECT * FROM oilrig_position WHERE oilrig_hash = ?', { oilrig_hash }, function(oilrigs)
          Oilrigs = oilrigs
          Gotrigs = true
     end)
end

function InsertInfromation(options)
     MySQL.Async.insert('INSERT INTO oilrig_position (citizenid,name,oilrig_hash,position,metadata) VALUES (?,?,?,?,?)',
          {
               options.citizenid,
               options.name,
               options.oilrig_hash,
               json.encode(options.position),
               json.encode(options.metadata)
          }
          , function(id)
          print(id)
     end)
end

function UpdateOilrigMetadata(options)
     MySQL.Async.execute('UPDATE oilrig_position SET metadata = ? WHERE citizenid = ? AND oilrig_hash = ?',
          { json.encode(options.metadata), options.citizenid, options.oilrig_hash }
     )
end

function equals(o1, o2)
     print_table(o1)
     print('GetAllOilrigsFromDatabase')
     print_table(o2)

end
