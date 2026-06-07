import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { type InsertAutoTimeSettings2, type AutoTimeSettings2 } from "@shared/schema";
import { api } from "@shared/routes";
import { useToast } from "@/hooks/use-toast";

export function useAutoTimeSettings2() {
  return useQuery({
    queryKey: [api.autoTimeSettings2.get.path],
    queryFn: async () => {
      try {
        const res = await fetch(api.autoTimeSettings2.get.path, { credentials: "include" });
        if (!res.ok) {
          if (res.status === 404) {
            return null; // No settings found yet
          }
          throw new Error("Failed to fetch auto time settings 2");
        }
        const data = await res.json();
        return data as AutoTimeSettings2 | null;
      } catch (error) {
        console.error("Error fetching auto time settings 2:", error);
        return null; // Return null on error to show component anyway
      }
    },
    retry: false, // Don't retry on error
  });
}

export function useSaveAutoTimeSettings2() {
  const queryClient = useQueryClient();
  const { toast } = useToast();

  return useMutation({
    mutationFn: async (data: InsertAutoTimeSettings2) => {
      const res = await fetch(api.autoTimeSettings2.create.path, {
        method: api.autoTimeSettings2.create.method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
        credentials: "include",
      });

      if (!res.ok) {
        const error = await res.json();
        throw new Error(error.message || "Failed to save auto time settings 2");
      }
      return await res.json() as AutoTimeSettings2;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [api.autoTimeSettings2.get.path] });
      toast({ 
        title: "Configuración Guardada", 
        description: "Tu configuración de registro automático 2 ha sido guardada exitosamente." 
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

export function useAdminAutoTimeSettings2() {
  return useQuery({
    queryKey: [api.autoTimeSettings2.adminList.path],
    queryFn: async () => {
      const res = await fetch(api.autoTimeSettings2.adminList.path, { credentials: "include" });
      if (!res.ok) throw new Error("Failed to fetch auto time settings 2");
      return await res.json() as (AutoTimeSettings2 & { userFullName: string })[];
    },
  });
}
