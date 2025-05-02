using Godot;
using System;

public partial class DirectionalLight3d : DirectionalLight3D
{


	public void ReadJson(string filePath)
	{
		// Datei-Pfad laden
		 // Stelle sicher, dass Globals.Path in deinem Projekt korrekt definiert ist
		

		if (FileAccess.FileExists(filePath))
		{
			using var dataFile = FileAccess.Open(filePath, FileAccess.ModeFlags.Read);
			if (dataFile == null)
			{
				GD.PrintErr("Fehler beim Öffnen der Datei.");
				return;
			}

			// Erste Zeile einlesen und Meta-Informationen parsen
			string lineMeta = dataFile.GetLine();
			var jsonMeta = Json.ParseString(lineMeta);

			int s = 10000;
			int sc = 0;
			int i = 1;

			while (!dataFile.EofReached())
			{
				ulong byteOffset = dataFile.GetPosition();

				string line = dataFile.GetLine();

				if (string.IsNullOrWhiteSpace(line))
					continue;

				var json = Json.ParseString(line); // Nutze ggf. das Ergebnis weiter

				if (sc == s)
				{
					sc = 0;
					GD.Print(i * s);
					i++;
				}
				sc++;
			}
		}
		else
		{
			GD.PrintErr("Datei nicht gefunden: " + filePath);
		}
	}
}
