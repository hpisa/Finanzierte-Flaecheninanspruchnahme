library(data.table)


data_dir <- "../data/"
bundesland_dir <- paste0(data_dir,"bundeslaender/")

df_emz <- data.frame(read.csv2(paste0(data_dir,"emz.csv")))

land_folders <- list.files(bundesland_dir)

# file (d.h. eine Gemeinde) aus land_folder (d.h. Bundesland) als dataframe einlesen
get_df <- function(land_folder,file){
  return(data.frame(read.csv2(paste0(bundesland_dir,land_folder,"/",file))) )
}

# alle files (Gemeinden) eines land_folder (Bundeslandes) einlesen und in
# einem gro?en gemeinsamen dataframe abspeichern
get_land_df <- function(land_folder){
  land_files <- list.files( paste0(bundesland_dir,land_folder) )
  files_df <- lapply(land_files,function(file) get_df(land_folder,file))
  df_land <- rbindlist(files_df)
  return(df_land)
}


#################################################
# V1: Alle Bundeslaender in einem Dataframe abspeichern
# ACHTUNG: zu gro? fuer Excel! Fuer Excel-Darstellung s. unten
#################################################

# Alle Bundeslaender (alle Gemeinden) einlesen...
laender_dfs <- lapply(land_folders, get_land_df)
# ... und daraus ein dataframe machen
df <- rbindlist(laender_dfs)

# mit den "Ertragsmesszahlen" aus dem emz.csv file mergen
df <- merge(df, df_emz[, c("BA","NU","EMZ_plus")], by = c("BA","NU"))

# EMZ_plus ist noch nicht flaechenabhaengig (waehrend Agrar-EMZ = Flaeche in Ar * Wertzahl)
# df$FLAECHE ist in qm -> rechne in Ar um und multipliziere mit EMZ_plus-Spalte
df$EMZ_plus <- df$FLAECHE/100 * df$EMZ_plus

df$EMZ_plus <- ifelse(is.na(df$EMZ), df$EMZ_plus, df$EMZ)  #die Agrar-EMZ in die EMZ-plus-Spalte speichern, ueberall dort, wo EMZ nicht NAN


print(paste0("NANs in EMZ_plus nach vorhandenen EMZ = ", sum(is.na(df$EMZ_plus))))

# da manche Agrarflaechen keine BEV-EMZ haben, gibt es noch einige NANs in der EMZ_plus-Spalte
# => fuer diese Agrarflaechen nehmen wir den gewichteten Gemeinde-Mittelwert der Agrarflaechen-EMZ (pro Flaeche mal Flaeche):
emz_mean_by_KGNR <- df[!is.na(df$EMZ), list(EMZ_mean = weighted.mean(EMZ/FLAECHE, FLAECHE)), by = KG.NR]
    # Achtung: Manche Gemeinden haben NUR NAN in EMZ-Spalte => die fallen hier raus

df <- merge(df, emz_mean_by_KGNR, by = "KG.NR", all.x = TRUE)  # Mittelwerte dazuspeichern
    # all.x = TRUE garantiert, dass alle Zeilen von df gespeichert werden, selbst wenn eine
    # entsprechende KG.NR in emz_mean_by_KGNR fehlt (weil die Gemeinde nur NANs in EMZ-Spalte hatte)
df$EMZ_plus <- ifelse(is.na(df$EMZ_plus), round(df$EMZ_mean * df$FLAECHE, 2), df$EMZ_plus)  #ueberall, wo EMZ_plus noch NAN ist, nimm Mittelwert/qm stattdessen und multipliziere mit Flaeche

print(paste0("NANs in EMZ_plus nach Gemeindeschnitt-Hinzufügung = ", sum(is.na(df$EMZ_plus))))

# => Handvoll Agrar-Grundstuecke haben immer noch NAN in EMZ_plus (weil Gemeinde keine einzige Agrar-EMZ hat)
# => nimm hier Bundesland-Mittel!
emz_mean_land <- weighted.mean(df$EMZ/df$FLAECHE, df$FLAECHE, na.rm = TRUE)  # gewichtetes Mittel pro Fläche ohne NAs
df$EMZ_plus <- ifelse(is.na(df$EMZ_plus), round(emz_mean_land * df$FLAECHE, 2), df$EMZ_plus)

print(paste0("NANs in EMZ_plus nach Landschnitt-Hinzufügung = ", sum(is.na(df$EMZ_plus))))


write.csv2(df[, c("KG.NR","GST.NR","BA","NU","FLAECHE","EMZ","EMZ_plus")],
           paste0(data_dir,"gesamt-oesterreich_emz-plus.csv"),
           row.names = FALSE)



#################################################
# V2: Da die obige Ergebnistabelle zu gro? ist fuer Excel, ist es
# sinnvoller, die Bundeslaender einzeln zu lassen und au?erdem nach
# der max. Anzahl von Excel-Zeilen zu sub-unterteilen
#################################################

max_excel_rows <- 1048575


for(land_folder in land_folders){ #gehe alle Bundeslaender durch
  
  print(land_folder)  #um Fortschritt zu sehen
  land <- strsplit(land_folder,"_")[[1]][3]  #speicher den Bundesland-Namen als String
  
  df_land <- get_land_df(land_folder)
  #df_land = ein df mit allen Gemeinden des aktuellen Bundeslandes
  
  df_land <- merge(df_land, df_emz[, c("BA","NU","EMZ_plus")], by = c("BA","NU"))
  #df_land um die Ertragsmesszahlen aus emz.csv erweitern (neue EMZ_plus-Spalte)
  
  # mache EMZ_plus flaechenabhaengig (wie Agrar-EMZ = Flaeche in Ar * Wertzahl)
  # df$FLAECHE ist in qm -> rechne in Ar um und multipliziere mit EMZ_plus-Spalte
  df_land$EMZ_plus <- df_land$FLAECHE/100 * df_land$EMZ_plus
  
  df_land$EMZ_plus <- ifelse(is.na(df_land$EMZ), df_land$EMZ_plus, df_land$EMZ)  #kopiere die Agrar-EMZ, wo vorhanden, in die EMZ_plus-Spalte
  
  print(paste0("NANs in EMZ_plus nach vorhandenen EMZ in ", land, " = ", sum(is.na(df_land$EMZ_plus))))
  
  
  # da manche Agrarflaechen keine BEV-EMZ haben, gibt es noch einige NANs in der EMZ_plus-Spalte
  # => fuer diese Agrarflaechen nehmen wir den Gemeinde-Mittelwert der Agrarflaechen-EMZ (pro Flaeche mal Flaeche):
  emz_mean_by_KGNR <- df_land[!is.na(df_land$EMZ),
                              list(EMZ_mean = weighted.mean(EMZ/FLAECHE, FLAECHE)),
                              by = KG.NR]   # Achtung: Manche Gemeinden haben NUR NAN in EMZ-Spalte => die fallen hier raus
  
  df_land <- merge(df_land, emz_mean_by_KGNR, by = "KG.NR", all.x = TRUE)  # Mittelwerte dazuspeichern
    # all.x = TRUE garantiert, dass alle Zeilen von df_land gespeichert werden, selbst wenn eine entsprechende KG.NR in emz_mean_by_KGNR fehlt
  df_land$EMZ_plus <- ifelse(is.na(df_land$EMZ_plus),
                             round(df_land$EMZ_mean * df_land$FLAECHE, 2),
                             df_land$EMZ_plus)  #ueberall, wo EMZ_plus noch NAN ist, nimm Mittelwert stattdessen
  
  print(paste0("NANs in EMZ_plus nach Gemeinde-Schnitt in ", land, " = ", sum(is.na(df_land$EMZ_plus))))
  
  # => Handvoll Agrar-Grundstuecke haben immer noch NAN in EMZ_plus (weil Gemeinde keine einzige Agrar-EMZ hat)
  # => nimm hier gewichtetes Bundesland-Mittel!
  if(sum(is.na(df_land$EMZ_plus))>0) {
    emz_mean_land <- weighted.mean(df_land$EMZ/df_land$FLAECHE, df_land$FLAECHE, na.rm = TRUE)
    df_land$EMZ_plus <- ifelse(is.na(df_land$EMZ_plus),
                               round(emz_mean_land * df_land$FLAECHE, 2),
                               df_land$EMZ_plus)
    print(paste0("NANs in EMZ_plus nach Land-Schnitt in ", land, " = ", sum(is.na(df_land$EMZ_plus))))
  }
  
  df_land <- df_land[order(df_land$KG.NR)]  #Reihenfolge sollte an sich eh schon stimmen (aufsteigend nach Gemeindenr), nur um fuer den naechsten Schritt sicher zu sein
  
  # Bundesland in mehrere csv-Dateien unterteilen, sodass keine die
  # maximale Laenge von Excel ueberschreitet, aber ohne in der Mitte einer
  # Gemeinde abzuschneiden:
 
  while(nrow(df_land) > 0){
    print(paste0("Remaining number of rows to be saved = ", nrow(df_land)))
    
    if(nrow(df_land) > max_excel_rows){  #ist die verbliebene Datenmenge zu gro??
      df_save <- head(df_land,max_excel_rows) #speicher die ersten max_excel_rows heraus
      last_kg_nr <- tail(df_save,1)$KG.NR  #die Gemeindenummer der letzten Zeile
      df_save <- df_save[df_save$KG.NR < last_kg_nr]
      #=> speicher nur die Zeilen bis zur letzten vollstaendigen Gemeinde (d.h. die vorletzte KG-Nr)
    } else {
      df_save <- df_land
    }
    
    last_kg_nr <- tail(df_save,1)$KG.NR  #hoechste KG-Nr  in df_save nach bei-letzter-vollstaendiger-Gemeinde-Abschneiden
    first_kg_nr <- head(df_save,1)$KG.NR  #niedrigste KG-Nr in df_save
    
    write.csv2(df_save[,c("KG.NR","GST.NR","BA","NU","FLAECHE","EMZ","EMZ_plus")],
               paste0(data_dir,"bundeslaender_emz-plus/",land,
                      "_KGNR_",first_kg_nr,"-",last_kg_nr,
                      "_emz-plus.csv"),
               row.names = FALSE
               )
    
    df_land <- df_land[df_land$KG.NR > last_kg_nr]  #behalte fuer die naechste Iteration nur, was noch nicht in df_save abgespeichert wurde
    
  }
}
