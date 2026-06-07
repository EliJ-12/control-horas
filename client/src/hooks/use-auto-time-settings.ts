import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { type InsertAutoTimeSettings, type AutoTimeSettings } from "@shared/schema";
import { api } from "@shared/routes";
import { useToast } from "@/hooks/use-toast";

export function useAutoTimeSettings() {
  return useQuery({
    queryKey: [api.autoTimeSettings.get.path],
    queryFn: async () => {
      try {
        const res = await fetch(api.autoTimeSettings.get.path, { credentials: "include" });
        if (!res.ok) {
          if (res.status === 404) {
            return null; // No settings found yet
          }
          throw new Error("Failed to fetch auto time settings");
        }
        const data = await res.json();
        return data as AutoTimeSettings | null;
      } catch (error) {
        console.error("Error fetching auto time settings:", error);
        return null; // Return null on error to show component anyway
      }
    },
    retry: false, // Don't retry on error
  });
}

export function useSaveAutoTimeSettings() {
  const queryClient = useQueryClient();
  const { toast } = useToast();

  return useMutation({
    mutationFn: async (data: InsertAutoTimeSettings) => {
      const res = await fetch(api.autoTimeSettings.create.path, {
        method: api.autoTimeSettings.create.method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
        credentials: "include",
      });

      if (!res.ok) {
        const error = await res.json();
        throw new Error(error.message || "Failed to save auto time settings");
      }
      return await res.json() as AutoTimeSettings;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [api.autoTimeSettings.get.path] });
      toast({ 
        title: "Configuración Guardada", 
        description: "Tu configuración de registro automático ha sido guardada exitosamente." 
      });
    },
    onError: (error: Error) => {
      toast({ 
        title: "Error", 
        description: error.message, 
        variant: "destructive" 
      });
    },
  });
}

export function useAdminAutoTimeSettings() {
  return useQuery({
    queryKey: [api.autoTimeSettings.adminList.path],
    queryFn: async () => {
      const res = await fetch(api.autoTimeSettings.adminList.path, { credentials: "include" });
      if (!res.ok) throw new Error("Failed to fetch auto time settings");
      return await res.json() as (AutoTimeSettings & { userFullName: string })[];
    },
  });
}
