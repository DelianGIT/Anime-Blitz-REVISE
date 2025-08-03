--!strict
--// TYPE
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

return true