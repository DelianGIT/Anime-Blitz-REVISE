--// TYPES
export type Data = {
	Team: "A" | "B" | "None",

	CharacterData: {
		Name: string,
		Category: string,
		Stats: {
			Health: number
		}
	}?
}

--// FIELDS
return {"Team", "CharacterData"}