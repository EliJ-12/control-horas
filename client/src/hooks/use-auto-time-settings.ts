import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { type InsertAutoTimeSettings, type AutoTimeSettings } from "@shared/schema";
import { useToast } from "@/hooks/use-toast";

export function useAutoTimeSettings() {
  return useQuery({
    queryKey: ["/api/auto-time-settings"],
    queryFn: async () => {
      const res = await fetch("/api/auto-time-settings", { credentials: "include" });
      if (!res.ok) throw new Error("Failed to fetch auto time settings");
      const data = await res.json();
      return data as AutoTimeSettings | null;
    },
  });
}

export function useSaveAutoTimeSettings() {
  const queryClient = useQueryClient();
  const { toast } = useToast();

  return useMutation({
    mutationFn: async (data: InsertAutoTimeSettings) => {
      const res = await fetch("/api/auto-time-settings", {
        method: "POST",
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
      queryClient.invalidateQueries({ queryKey: ["/api/auto-time-settings"] });
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
    queryKey: ["/api/admin/auto-time-settings"],
    queryFn: async () => {
      const res = await fetch("/api/admin/auto-time-settings", { credentials: "include" });
      if (!res.ok) throw new Error("Failed to fetch auto time settings");
      return await res.json() as (AutoTimeSettings & { userFullName: string })[];
    },
  });
}
